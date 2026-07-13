package com.zone01.lets_play.DTOs.user;

public record LoginResponse(
    String token,
    String type,
    UserResponse user
) {}