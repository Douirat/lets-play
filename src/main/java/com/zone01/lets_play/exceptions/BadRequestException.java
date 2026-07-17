package com.zone01.lets_play.exceptions;

import org.springframework.http.HttpStatus;

/** Catch-all for malformed input that isn't covered by bean validation
 *  (e.g. a path variable that isn't a valid MongoDB ObjectId). -> 400 */
public class BadRequestException extends ApiException {
    public BadRequestException(String message) {
        super(HttpStatus.BAD_REQUEST, message);
    }

    public static BadRequestException invalidId(String id) {
        return new BadRequestException("'" + id + "' is not a valid resource id");
    }
}