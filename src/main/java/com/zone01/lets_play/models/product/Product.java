package com.zone01.lets_play.models.product;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@Data
@NoArgsConstructor
public class Product {
    private long id;
    private String name;
    private String description;
    private double price;
}