package com.weenie_hut_jr.the_salty_spitoon.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class IntegrityIssue {
    private String symbol;
    private LocalDateTime timestamp;
    private String issueType;
    private String description;
}