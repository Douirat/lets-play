package com.zone01.lets_play.services.product;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.models.product.Product;
import com.zone01.lets_play.repositories.product.ProductRepository;
import com.zone01.lets_play.security.SecurityUtils;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@AllArgsConstructor
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;

    @Override
    public ResponseDTO<List<Product>> getAllProducts() {
        return ResponseDTO.success("Products retrieved", productRepository.findAll());
    }

    @Override
    public ResponseDTO<Product> createProduct(Product product) {
        String currentUserId = SecurityUtils.currentUserId();
        product.setUserId(currentUserId); // never trust a client-supplied userId
        Product saved = productRepository.save(product);
        return ResponseDTO.success("Product created", saved);
    }

    @Override
    public ResponseDTO<Product> updateProduct(String id, Product update) {
        Product existing = productRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));

        existing.setName(update.getName());
        existing.setDescription(update.getDescription());
        existing.setPrice(update.getPrice());
        // userId is intentionally never overwritten here — ownership doesn't transfer on update

        Product saved = productRepository.save(existing);
        return ResponseDTO.success("Product updated", saved);
    }

    @Override
    public ResponseDTO<Void> deleteProduct(String id) {
        if (!productRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found");
        }
        productRepository.deleteById(id);
        return ResponseDTO.success("Product deleted", null);
    }
}