package com.zone01.lets_play.services.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.DTOs.user.UserDTO;
import com.zone01.lets_play.DTOs.user.UserLoginRequest;
import com.zone01.lets_play.models.user.User;

public interface UserService {
ResponseDTO<UserDTO> createUser(User user);
ResponseDTO<UserDTO> loginUser(UserLoginRequest loginRequest);
}