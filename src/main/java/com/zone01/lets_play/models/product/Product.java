package com.zone01.lets_play.models.product;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import jakarta.validation.constraints.*;

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
  @Id
    private String id;

    @NotBlank(message = "Product name is required")
    @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
    @Field("name")
    private String name;

    @Size(max = 500, message = "Description must not exceed 500 characters")
    @Field("description")
    private String description;

    @NotNull(message = "Price is required")
    @Positive(message = "Price must be greater than zero")
    @Field("price")
    private Double price;

    // References the owning User's id — this is the "n" side of the 1-to-n relationship
    @NotBlank(message = "userId is required")
    @Field("userId")
    private String userId;

}