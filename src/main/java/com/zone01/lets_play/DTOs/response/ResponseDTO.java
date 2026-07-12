package com.zone01.lets_play.DTOs.response;

import java.time.Instant;

public class ResponseDTO<T> {

    private String message;
    private T data;
    private Instant timestamp;

    public ResponseDTO(String message, T data) {
        this.message = message;
        this.data = data;
        this.timestamp = Instant.now();
    }

    public ResponseDTO() {
        this.timestamp = Instant.now();
    }

    public static <T> ResponseDTO<T> success(String message, T data) {
        return new ResponseDTO<>(message, data);
    }

    public static <T> ResponseDTO<T> success(T data) {
        return new ResponseDTO<>("Success", data);
    }

    public static <T> ResponseDTO<T> error(String message) {
        return new ResponseDTO<>(message, null);
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }

    public Instant getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Instant timestamp) {
        this.timestamp = timestamp;
    }

    @Override
    public String toString() {
        return "ResponseDTO{" +
                "message='" + message + '\'' +
                ", data=" + data +
                ", timestamp=" + timestamp +
                '}';
    }
}