package com.zone01.lets_play.exceptions;

import org.springframework.http.HttpStatus;

/** Authenticated, but not allowed to perform this action (role or ownership denied). -> 403 */
public class UnauthorizedActionException extends ApiException {
    public UnauthorizedActionException(String message) {
        super(HttpStatus.FORBIDDEN, message);
    }

    public static UnauthorizedActionException notOwnerOrAdmin() {
        return new UnauthorizedActionException("You must be the owner or an admin to perform this action");
    }

    public static UnauthorizedActionException adminOnly() {
        return new UnauthorizedActionException("This action is restricted to admins");
    }
}