package com.zone01.lets_play.repositories.product;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.zone01.lets_play.models.product.Product;

public interface ProductRepository extends MongoRepository<Product, String> {

}