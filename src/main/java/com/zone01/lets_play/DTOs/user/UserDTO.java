package com.zone01.lets_play.DTOs.user;

public record UserDTO(
    String id,
    String username,
    String email,
    String role
) {}