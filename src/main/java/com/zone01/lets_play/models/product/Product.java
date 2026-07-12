package com.zone01.lets_play.models.product;

import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@Data
@NoArgsConstructor
@Builder
@Document(collection = "products")
public class Product {
    private String id;
    private String name;
    private String description;
    private double price;
}