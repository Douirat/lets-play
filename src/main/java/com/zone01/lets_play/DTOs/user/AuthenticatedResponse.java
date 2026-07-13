package com.zone01.lets_play.DTOs.user;

public record AuthenticatedResponse(
    String token,
    String type,
    UserResponse user
) {}