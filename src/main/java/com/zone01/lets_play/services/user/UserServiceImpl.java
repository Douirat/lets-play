package com.zone01.lets_play.services.user;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.DTOs.user.AuthenticatedResponse;
import com.zone01.lets_play.DTOs.user.UserLoginRequest;
import com.zone01.lets_play.DTOs.user.UserRegisterRequest;
import com.zone01.lets_play.DTOs.user.UserResponse;
import com.zone01.lets_play.exceptions.DuplicateResourceException;
import com.zone01.lets_play.exceptions.InvalidCredentialsException;
import com.zone01.lets_play.models.role.Role;
import com.zone01.lets_play.models.user.User;
import com.zone01.lets_play.repositories.user.UserRepository;
import com.zone01.lets_play.security.JwtUtil;
import lombok.AllArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@AllArgsConstructor
@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @Override
    public ResponseDTO<UserResponse> createUser(UserRegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw DuplicateResourceException.emailAlreadyInUse(request.email());
        }

        User user = User.builder()
                .name(request.name())
                .email(request.email())
                .password(passwordEncoder.encode(request.password()))
                .role(userRepository.count() == 0 ? Role.ADMIN : Role.USER)
                .build();

        User savedUser = userRepository.save(user);

        return ResponseDTO.success(
                "User created successfully.",
                new UserResponse(savedUser.getId(), savedUser.getName(), savedUser.getEmail(), savedUser.getRole().name()));
    }

    @Override
    public ResponseDTO<AuthenticatedResponse> loginUser(UserLoginRequest loginRequest) {
        User user = userRepository.findByNameOrEmail(loginRequest.identifier())
                .orElseThrow(InvalidCredentialsException::new);

        if (!passwordEncoder.matches(loginRequest.password(), user.getPassword())) {
            throw new InvalidCredentialsException();
        }

        String token = jwtUtil.generateToken(user.getId(), user.getRole().name());
        UserResponse userResponse = new UserResponse(user.getId(), user.getName(), user.getEmail(), user.getRole().name());

        return ResponseDTO.success("Login successful.", new AuthenticatedResponse(token, "Bearer", userResponse));
    }
}