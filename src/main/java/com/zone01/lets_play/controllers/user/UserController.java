package com.zone01.lets_play.controllers.user;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.DTOs.user.UserResponse;
import com.zone01.lets_play.DTOs.user.AuthenticatedResponse;
import com.zone01.lets_play.DTOs.user.UserLoginRequest;
import com.zone01.lets_play.services.user.UserService;
import com.zone01.lets_play.models.user.User;


import jakarta.validation.Valid;

import lombok.AllArgsConstructor;

@RestController
@AllArgsConstructor
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    @PostMapping
    public ResponseEntity<ResponseDTO<UserResponse>> createUser(@Valid @ModelAttribute User user) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(userService.createUser(user));
    }

    @PostMapping("/login")
    public ResponseEntity<ResponseDTO<AuthenticatedResponse>> loginUser(@Valid @ModelAttribute UserLoginRequest loginRequest) {
        // Implementation for user login
        return ResponseEntity.ok().body(userService.loginUser(loginRequest));
    }

    
}