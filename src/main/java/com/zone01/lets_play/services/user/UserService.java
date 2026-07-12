package com.zone01.lets_play.services.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.models.user.User;

public interface UserService {
ResponseDTO<User> createUser(User user);
}