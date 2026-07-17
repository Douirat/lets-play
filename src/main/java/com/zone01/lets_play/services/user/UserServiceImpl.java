package com.zone01.lets_play.services.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.DTOs.user.UserResponse;
import com.zone01.lets_play.repositories.user.UserRepository;
import com.zone01.lets_play.DTOs.user.UserLoginRequest;
import com.zone01.lets_play.DTOs.user.AuthenticatedResponse;
import com.zone01.lets_play.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import com.zone01.lets_play.models.role.Role;


import com.zone01.lets_play.models.user.User;

@AllArgsConstructor
@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Override
    public ResponseDTO<UserResponse> createUser(User user) {

        if( user.getName() == null || user.getName().isEmpty() || user.getPassword() == null || user.getPassword().isEmpty() || user.getEmail() == null || user.getEmail().isEmpty()) {
            return ResponseDTO.error("All fields are required.");
        }

        if (userRepository.existsByEmail(user.getEmail())) {
            return ResponseDTO.error("User with this email already exists.");
        }

        if(userRepository.existsByName(user.getName())) {

        }

        if (userRepository.count() == 0) {
            user.setRole(Role.ADMIN);
        } else {
            user.setRole(Role.USER);
        }

        user.setPassword(passwordEncoder.encode(user.getPassword()));


        System.out.println("User role: " + user.getRole());


        User savedUser = userRepository.save(user);

        return ResponseDTO.success(
                "User created successfully.",
                new UserResponse(
                        savedUser.getId(),
                        savedUser.getName(),
                        savedUser.getEmail(),
                        savedUser.getRole().name()));
    }

    @Override
    public ResponseDTO<AuthenticatedResponse> loginUser(UserLoginRequest loginRequest) {
        User user = userRepository.findByNameOrEmail(loginRequest.identifier())
                .orElseThrow(() -> new RuntimeException("Invalid credentials"));

        if (!passwordEncoder.matches(loginRequest.password(), user.getPassword())) {
            throw new RuntimeException("Invalid credentials");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getRole().name());

        UserResponse userResponse = new UserResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole().name());

        AuthenticatedResponse response = new AuthenticatedResponse(
                token,
                "Bearer",
                userResponse);

        return ResponseDTO.success("Login successful.", response);
    }
}