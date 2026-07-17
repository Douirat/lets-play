package com.zone01.lets_play.controllers.product;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.models.product.Product;
import com.zone01.lets_play.services.product.ProductService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@AllArgsConstructor
@RequestMapping("/api/products")
public class ProductController {

    private final ProductService productService;

    @GetMapping
    public ResponseEntity<ResponseDTO<?>> getAllProducts() {
        return ResponseEntity.ok(productService.getAllProducts());
    }

    @PostMapping
    public ResponseEntity<ResponseDTO<Product>> createProduct(@Valid @ModelAttribute Product product) {
        return ResponseEntity.status(201).body(productService.createProduct(product));
    }

    @PreAuthorize("@productSecurity.isOwnerOrAdmin(#id, authentication)")
    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO<Product>> updateProduct(
            @PathVariable String id,
            @Valid @ModelAttribute Product update
    ) {
        return ResponseEntity.ok(productService.updateProduct(id, update));
    }

    @PreAuthorize("@productSecurity.isOwnerOrAdmin(#id, authentication)")
    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO<Void>> deleteProduct(@PathVariable String id) {
        return ResponseEntity.ok(productService.deleteProduct(id));
    }
}