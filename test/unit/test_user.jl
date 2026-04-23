using Test
using TypeDBClient3

# Unit tests for user management (user.jl).
# No TypeDB server required — exercises pure Julia logic only.

@testset "TypeDBUser – FFI handle aliases defined" begin
    @test TypeDBClient3.UserHandle    === Ptr{Cvoid}
    @test TypeDBClient3.UserIterHandle === Ptr{Cvoid}
end

@testset "TypeDBUser – FFI functions declared" begin
    @test isdefined(TypeDBClient3.FFI, :users_all)
    @test isdefined(TypeDBClient3.FFI, :users_contains)
    @test isdefined(TypeDBClient3.FFI, :users_create)
    @test isdefined(TypeDBClient3.FFI, :users_get)
    @test isdefined(TypeDBClient3.FFI, :users_get_current_user)
    @test isdefined(TypeDBClient3.FFI, :user_get_name)
    @test isdefined(TypeDBClient3.FFI, :user_update_password)
    @test isdefined(TypeDBClient3.FFI, :user_delete)
    @test isdefined(TypeDBClient3.FFI, :user_drop)
    @test isdefined(TypeDBClient3.FFI, :user_iterator_next)
    @test isdefined(TypeDBClient3.FFI, :user_iterator_drop)
end

@testset "TypeDBUser – public API exported" begin
    @test isdefined(TypeDBClient3, :TypeDBUser)
    @test isdefined(TypeDBClient3, :list_users)
    @test isdefined(TypeDBClient3, :contains_user)
    @test isdefined(TypeDBClient3, :create_user)
    @test isdefined(TypeDBClient3, :get_user)
    @test isdefined(TypeDBClient3, :get_current_user)
    @test isdefined(TypeDBClient3, :user_name)
    @test isdefined(TypeDBClient3, :update_user_password)
    @test isdefined(TypeDBClient3, :delete_user)
end
