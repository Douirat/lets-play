package com.zone01.lets_play.services.exception;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import com.zone01.lets_play.exceptions.*;

import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // --- All custom application exceptions share one handler, since each ---
    // --- already carries its own HttpStatus (see ApiException). ---
    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ResponseDTO<Void>> handleApiException(ApiException ex) {
        return ResponseEntity.status(ex.getStatus())
                .body(ResponseDTO.error(ex.getMessage()));
    }

    // --- 400: bean validation failures on @Valid @ModelAttribute/@RequestBody ---
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ResponseDTO<Map<String, String>>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.put(error.getField(), error.getDefaultMessage());
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ResponseDTO<>("Validation failed", fieldErrors));
    }

    // --- 401: Spring Security's own bad-credentials exception, in case it's ---
    // --- thrown directly by an AuthenticationManager instead of your service ---
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ResponseDTO<Void>> handleBadCredentials(BadCredentialsException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ResponseDTO.error("Invalid credentials"));
    }

    // --- 401: any other Spring Security authentication failure ---
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ResponseDTO<Void>> handleAuthentication(AuthenticationException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ResponseDTO.error("Authentication required"));
    }

    // --- 403: Spring Security's own denial, thrown automatically by ---
    // --- @PreAuthorize / @PostAuthorize when the SpEL expression is false ---
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ResponseDTO<Void>> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ResponseDTO.error("You do not have permission to perform this action"));
    }

    // --- fallback for any leftover ResponseStatusException not yet migrated ---
    // --- to a custom ApiException subclass ---
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ResponseDTO<Void>> handleResponseStatus(ResponseStatusException ex) {
        String message = ex.getReason() != null ? ex.getReason() : "Request failed";
        return ResponseEntity.status(ex.getStatusCode())
                .body(ResponseDTO.error(message));
    }

    // --- catch-all: nothing should ever surface as a raw, unhandled 5XX ---
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ResponseDTO<Void>> handleUnexpected(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ResponseDTO.error("An unexpected error occurred"));
    }
}