package com.zone01.lets_play.services.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.DTOs.user.UserDTO;
import com.zone01.lets_play.repositories.user.UserRepository;
import com.zone01.lets_play.DTOs.user.UserLoginRequest;

import lombok.AllArgsConstructor;

import com.zone01.lets_play.models.user.User;
@AllArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;


    @Override
    public ResponseDTO<UserDTO> createUser(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            return ResponseDTO.error("User with this email already exists.");
        }

        User savedUser = userRepository.save(user);
        return ResponseDTO.success("User created successfully.", new UserDTO(savedUser.getId(), savedUser.getName(), savedUser.getEmail(), savedUser.getRole()));
    }

    @Override
    public ResponseDTO<UserDTO> loginUser(UserLoginRequest loginRequest) {
        User user = userRepository.findByNameOrEmail(loginRequest.getUserOrEmail())
                .orElse(null);

        if (user == null || !user.getPassword().equals(loginRequest.getPassword())) {
            return ResponseDTO.error("Invalid email or password.");
        }

        return ResponseDTO.success("Login successful.", new UserDTO(user.getId(), user.getName(), user.getEmail(), user.getRole()));
    }
}