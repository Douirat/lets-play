package com.zone01.lets_play.DTOs.product;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record ProductUpdateRequest(
        @NotBlank(message = "Product name is required")
        @Size(min = 2, max = 100)
        String name,

        @Size(max = 500)
        String description,

        @NotNull(message = "Price is required")
        @Positive(message = "Price must be greater than zero")
        Double price
) {}