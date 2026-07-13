package com.zone01.lets_play.security;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import com.zone01.lets_play.models.user.User;
import java.util.*;

/*
*Client
*   │
*   │ Authorization: Bearer <JWT>
*   ▼
*JWT Filter
*   │
*   │ 1. Extract token
*   │ 2. Validate signature
*   │ 3. Read claims (subject, expiration, ...)
*   ▼
*UserDetailsService
*   │
*   │ Load user from MongoDB
*   ▼
*CustomUserDetails
*   │
*   ▼
*SecurityContextHolder
*   │
*   ▼
*Controller
*/

public class CustomUserDetails implements UserDetails {

    private final User user;

    public CustomUserDetails(User user) {
        this.user = user;
    }

    public String getId() {
        return user.getId();
    }

    public User getUser() {
        return user;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()));
    }

    @Override
    public String getPassword() {
        return user.getPassword();
    }

    @Override
    public String getUsername() {
        return user.getEmail();
    }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return true; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() { return true; }
}