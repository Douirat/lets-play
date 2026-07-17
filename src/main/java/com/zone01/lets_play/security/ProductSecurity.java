package com.zone01.lets_play.security;

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

        if (principal.getUser().getRole() == Role.ADMIN) {
            return true;
        }

        return productRepository.findById(productId)
                .map(product -> product.getUserId().equals(principal.getId()))
                .orElse(false); // no product -> not authorized; controller still 404s cleanly afterward
    }
}