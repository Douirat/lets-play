package com.zone01.lets_play.repositories.user;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

import java.util.*;

import com.zone01.lets_play.models.user.User;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<User> findByName(String name);

    @Query("{ '$or': [ { 'name': ?0 }, { 'email': ?0 } ] }")
    Optional<User> findByNameOrEmail(String login);
}