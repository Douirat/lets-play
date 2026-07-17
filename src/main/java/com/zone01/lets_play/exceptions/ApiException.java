package com.zone01.lets_play.exceptions;

import org.springframework.http.HttpStatus;

/**
 * Base type for all custom application exceptions. Carries the HTTP status
 * that should be returned, so GlobalExceptionHandler can handle every
 * subclass with a single handler instead of one method per exception type.
 */
public abstract class ApiException extends RuntimeException {

    private final HttpStatus status;

    protected ApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}