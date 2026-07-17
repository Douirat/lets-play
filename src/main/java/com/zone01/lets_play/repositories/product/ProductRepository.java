package com.zone01.lets_play.repositories.product;

import com.zone01.lets_play.models.product.Product;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ProductRepository extends MongoRepository<Product, String> {
    List<Product> findByUserId(String userId);
}