package com.weenie_hut_jr.the_salty_spitoon.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * 대시보드 컨트롤러
 */
@Slf4j
@Controller
@RequiredArgsConstructor
public class DashboardController {

    /**
     * 메인 대시보드 페이지
     */
    @GetMapping("/dashboard")
    public String dashboard(Model model) {
        log.info("Dashboard accessed");
        return "dashboard";
    }

    /**
     * 홈 리다이렉트
     */
    @GetMapping("/")
    public String home() {
        return "redirect:/dashboard";
    }
}
