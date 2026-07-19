package com.zone01.lets_play.services.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.DTOs.user.UserResponse;
import com.zone01.lets_play.DTOs.user.*;



// UserService.java
public interface UserService {
    ResponseDTO<UserResponse> createUser(UserRegisterRequest request);
    ResponseDTO<AuthenticatedResponse> loginUser(UserLoginRequest loginRequest);
}