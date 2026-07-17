package com.zone01.lets_play.exceptions;

import org.springframework.http.HttpStatus;

/** A requested resource (user, product) does not exist. -> 404 */
public class ResourceNotFoundException extends ApiException {
    public ResourceNotFoundException(String message) {
        super(HttpStatus.NOT_FOUND, message);
    }

    public static ResourceNotFoundException product(String id) {
        return new ResourceNotFoundException("Product not found with id: " + id);
    }

    public static ResourceNotFoundException user(String id) {
        return new ResourceNotFoundException("User not found with id: " + id);
    }
}