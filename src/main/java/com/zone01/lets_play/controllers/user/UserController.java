package com.zone01.lets_play.controllers.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.DTOs.user.AuthenticatedResponse;
import com.zone01.lets_play.DTOs.user.UserLoginRequest;
import com.zone01.lets_play.DTOs.user.UserRegisterRequest;
import com.zone01.lets_play.DTOs.user.UserResponse;
import com.zone01.lets_play.services.user.UserService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@AllArgsConstructor
@RequestMapping("/api/auth/")
public class UserController {

    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<ResponseDTO<UserResponse>> createUser(@Valid @ModelAttribute UserRegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(userService.createUser(request));
    }

    @PostMapping("/login")
    public ResponseEntity<ResponseDTO<AuthenticatedResponse>> loginUser(
            @Valid @ModelAttribute UserLoginRequest loginRequest) {
        return ResponseEntity.ok().body(userService.loginUser(loginRequest));
    }

    // UserManagementController.java — add
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO<UserResponse>> updateUser(
            @PathVariable String id,
            @Valid @ModelAttribute UserUpdateRequest request) {
        return ResponseEntity.ok(userService.updateUser(id, request));
    }
}