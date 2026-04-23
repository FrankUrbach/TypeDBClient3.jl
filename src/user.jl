# ─── TypeDBUser struct ────────────────────────────────────────────────────────

"""
    TypeDBUser

Represents a TypeDB user account.  Holds a reference to the parent driver and
the user handle returned by the C API.

Obtain via [`get_user`](@ref), [`get_current_user`](@ref), or through iteration
of [`list_users`](@ref).
"""
mutable struct TypeDBUser
    driver::TypeDBDriver
    handle::UserHandle
    _name::String
    _dropped::Bool

    function TypeDBUser(driver::TypeDBDriver, handle::UserHandle)
        handle == C_NULL && error("users_get returned NULL")
        name_cstr = FFI.user_get_name(handle)
        name = typedb_string(name_cstr)
        obj = new(driver, handle, name, false)
        finalizer(obj) do u
            u._dropped || (u._dropped = true; FFI.user_drop(u.handle))
        end
        obj
    end
end

Base.show(io::IO, u::TypeDBUser) = print(io, "TypeDBUser(\"$(u._name)\")")

# ─── User management operations ───────────────────────────────────────────────

"""
    list_users(driver) -> Vector{TypeDBUser}

Return all user accounts on the server.
"""
function list_users(driver::TypeDBDriver)::Vector{TypeDBUser}
    iter = @checkerr FFI.users_all(driver.handle)
    iter == C_NULL && return TypeDBUser[]
    users = TypeDBUser[]
    try
        while true
            h = FFI.user_iterator_next(iter)
            check_and_throw()
            h == C_NULL && break
            push!(users, TypeDBUser(driver, h))
        end
    finally
        FFI.user_iterator_drop(iter)
    end
    users
end

"""
    contains_user(driver, username) -> Bool

Return `true` if a user named `username` exists on the server.
"""
function contains_user(driver::TypeDBDriver, username::AbstractString)::Bool
    GC.@preserve username begin
        result = @checkerr FFI.users_contains(
            driver.handle,
            Base.unsafe_convert(Cstring, Base.cconvert(Cstring, username)))
    end
    result
end

"""
    create_user(driver, username, password)

Create a new user account.  Throws if the user already exists.
"""
function create_user(driver::TypeDBDriver, username::AbstractString,
                     password::AbstractString)
    GC.@preserve username password begin
        @checkerr FFI.users_create(
            driver.handle,
            Base.unsafe_convert(Cstring, Base.cconvert(Cstring, username)),
            Base.unsafe_convert(Cstring, Base.cconvert(Cstring, password)))
    end
    nothing
end

"""
    get_user(driver, username) -> TypeDBUser

Retrieve the user named `username`.  Throws if the user does not exist.
"""
function get_user(driver::TypeDBDriver, username::AbstractString)::TypeDBUser
    h = GC.@preserve username begin
        @checkerr FFI.users_get(
            driver.handle,
            Base.unsafe_convert(Cstring, Base.cconvert(Cstring, username)))
    end
    TypeDBUser(driver, h)
end

"""
    get_current_user(driver) -> TypeDBUser

Return the user account corresponding to the current driver connection.
"""
function get_current_user(driver::TypeDBDriver)::TypeDBUser
    h = @checkerr FFI.users_get_current_user(driver.handle)
    TypeDBUser(driver, h)
end

"""
    user_name(user::TypeDBUser) -> String
"""
user_name(user::TypeDBUser) = user._name

"""
    update_user_password(user::TypeDBUser, new_password)

Change the password of `user`.
"""
function update_user_password(user::TypeDBUser, new_password::AbstractString)
    GC.@preserve new_password begin
        @checkerr FFI.user_update_password(
            user.handle,
            Base.unsafe_convert(Cstring, Base.cconvert(Cstring, new_password)))
    end
    nothing
end

"""
    update_user_password(driver, username, new_password)

Change the password of the user named `username`.
"""
function update_user_password(driver::TypeDBDriver, username::AbstractString,
                               new_password::AbstractString)
    update_user_password(get_user(driver, username), new_password)
end

"""
    delete_user(user::TypeDBUser)

Permanently delete a user account.
"""
function delete_user(user::TypeDBUser)
    FFI.user_delete(user.handle)
    user._dropped = true
    check_and_throw()
    nothing
end

"""
    delete_user(driver, username)

Permanently delete the user named `username`.
"""
function delete_user(driver::TypeDBDriver, username::AbstractString)
    delete_user(get_user(driver, username))
end
