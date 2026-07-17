package com.zone01.lets_play.services.product;

import com.zone01.lets_play.DTOs.response.ResponseDTO;
import com.zone01.lets_play.models.product.Product;

import java.util.List;

public interface ProductService {
    ResponseDTO<List<Product>> getAllProducts();
    ResponseDTO<Product> createProduct(Product product);
    ResponseDTO<Product> updateProduct(String id, Product update);
    ResponseDTO<Void> deleteProduct(String id);
}