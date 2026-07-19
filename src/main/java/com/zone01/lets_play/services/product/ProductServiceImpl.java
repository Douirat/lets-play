package com.zone01.lets_play.services.product;

import com.zone01.lets_play.DTOs.product.ProductCreateRequest;
import com.zone01.lets_play.DTOs.product.ProductUpdateRequest;
import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.exceptions.ResourceNotFoundException;
import com.zone01.lets_play.models.product.Product;
import com.zone01.lets_play.repositories.product.ProductRepository;
import com.zone01.lets_play.security.SecurityUtils;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

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
    public ResponseDTO<Product> createProduct(ProductCreateRequest request) {
        Product product = Product.builder()
                .name(request.name())
                .description(request.description())
                .price(request.price())
                .userId(SecurityUtils.currentUserId())
                .build();

        return ResponseDTO.success("Product created", productRepository.save(product));
    }

    @Override
    public ResponseDTO<Product> updateProduct(String id, ProductUpdateRequest update) {
        Product existing = productRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.product(id));

        existing.setName(update.name());
        existing.setDescription(update.description());
        existing.setPrice(update.price());
        // userId intentionally untouched — ownership doesn't transfer on update

        return ResponseDTO.success("Product updated", productRepository.save(existing));
    }

    @Override
    public ResponseDTO<Void> deleteProduct(String id) {
        if (!productRepository.existsById(id)) {
            throw ResourceNotFoundException.product(id);
        }
        productRepository.deleteById(id);
        return ResponseDTO.success("Product deleted", null);
    }

    // ProductServiceImpl.java — add
    @Override
    public ResponseDTO<Product> getProductById(String id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.product(id));
        return ResponseDTO.success("Product retrieved", product);
    }
}