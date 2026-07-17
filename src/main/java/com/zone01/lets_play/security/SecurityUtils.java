package com.zone01.lets_play.security;

import org.springframework.security.core.context.SecurityContextHolder;

public class SecurityUtils {

    private SecurityUtils() {}

    public static String currentUserId() {
        var principal = (CustomUserDetails) SecurityContextHolder.getContext()
                .getAuthentication()
                .getPrincipal();
        return principal.getId();
    }
}