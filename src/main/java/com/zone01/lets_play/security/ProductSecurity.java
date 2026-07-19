package com.zone01.lets_play.security;

import com.zone01.lets_play.exceptions.ResourceNotFoundException;
import com.zone01.lets_play.models.role.*;
import com.zone01.lets_play.repositories.product.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

@Component("productSecurity")
@RequiredArgsConstructor
public class ProductSecurity {

    private final ProductRepository productRepository;

    public boolean isOwnerOrAdmin(String productId, Authentication authentication) {
        if (!(authentication.getPrincipal() instanceof CustomUserDetails principal)) {
            return false;
        }

        var product = productRepository.findById(productId)
                .orElseThrow(() -> ResourceNotFoundException.product(productId));

        if (principal.getUser().getRole() == Role.ADMIN) {
            return true;
        }

        return product.getUserId().equals(principal.getId());
    }
}