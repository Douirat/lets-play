package com.zone01.lets_play.services.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.repositories.user.UserRepository;

import lombok.AllArgsConstructor;

import com.zone01.lets_play.models.user.User;
@AllArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;


    @Override
    public ResponseDTO<User> createUser(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            return ResponseDTO.error("User with this email already exists.");
        }

        User savedUser = userRepository.save(user);
        return ResponseDTO.success("User created successfully.", savedUser);
        
    }
}