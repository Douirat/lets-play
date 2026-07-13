package com.zone01.lets_play.DTOs.user;

public record UserLoginRequest(
    String identifier,
    String password
) {}