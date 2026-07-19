package com.zone01.lets_play.services.product;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.models.product.Product;
import com.zone01.lets_play.DTOs.product.*;

import java.util.List;

// ProductService.java
public interface ProductService {
    ResponseDTO<List<Product>> getAllProducts();

    ResponseDTO<Product> createProduct(ProductCreateRequest request);

    ResponseDTO<Product> updateProduct(String id, ProductUpdateRequest update);

    ResponseDTO<Void> deleteProduct(String id);

    // ProductService.java — add to the interface
    ResponseDTO<Product> getProductById(String id);
}