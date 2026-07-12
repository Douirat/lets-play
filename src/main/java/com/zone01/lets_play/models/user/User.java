package com.zone01.lets_play.models.user;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import org.springframework.data.annotation.Id;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class User {
@Id
private long id;

private String name;

private String email;

private String password;

private String role;
}