package com.zone01.lets_play.services.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.DTOs.user.UserResponse;
import com.zone01.lets_play.DTOs.user.*;
import com.zone01.lets_play.models.user.User;


public interface UserService {
ResponseDTO<UserResponse> createUser(User user);
ResponseDTO<AuthenticatedResponse> loginUser(UserLoginRequest loginRequest);
}