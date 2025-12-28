package com.weenie_hut_jr.the_salty_spitoon.controller;

import com.weenie_hut_jr.the_salty_spitoon.entity.User;
import com.weenie_hut_jr.the_salty_spitoon.entity.UserWatchlist;
import com.weenie_hut_jr.the_salty_spitoon.entity.WatchlistGroup;
import com.weenie_hut_jr.the_salty_spitoon.repository.UserRepository;
import com.weenie_hut_jr.the_salty_spitoon.service.WatchlistService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 워치리스트 Controller
 */
@Slf4j
@Controller
@RequiredArgsConstructor
public class WatchlistController {

    private final WatchlistService watchlistService;
    private final UserRepository userRepository;

    /**
     * 사용자 ID 조회 헬퍼
     */
    private Long getUserId(UserDetails userDetails) {
        if (userDetails == null) {
            return null;
        }
        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElse(null);
        return user != null ? user.getId() : null;
    }

    // ========================================
    // 페이지
    // ========================================

    /**
     * 워치리스트 페이지
     */
    @GetMapping("/watchlist")
    public String watchlistPage(@AuthenticationPrincipal UserDetails userDetails, Model model) {
        Long userId = getUserId(userDetails);
        
        if (userId == null) {
            return "redirect:/login";
        }

        List<WatchlistGroup> groups = watchlistService.getGroups(userId);
        List<UserWatchlist> watchlist = watchlistService.getWatchlist(userId);

        model.addAttribute("groups", groups);
        model.addAttribute("watchlist", watchlist);

        return "watchlist";
    }

    // ========================================
    // 워치리스트 API
    // ========================================

    /**
     * 종목 좋아요 토글
     */
    @PostMapping("/api/watchlist/toggle")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> toggleWatchlist(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, String> request) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("success", false);
                response.put("message", "로그인이 필요합니다.");
                return ResponseEntity.status(401).body(response);
            }

            String symbol = request.get("symbol");
            if (symbol == null || symbol.isEmpty()) {
                response.put("success", false);
                response.put("message", "종목 심볼이 필요합니다.");
                return ResponseEntity.badRequest().body(response);
            }

            boolean isAdded = watchlistService.toggleWatchlist(userId, symbol);
            
            response.put("success", true);
            response.put("isInWatchlist", isAdded);
            response.put("message", isAdded ? "워치리스트에 추가되었습니다." : "워치리스트에서 제거되었습니다.");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("워치리스트 토글 실패", e);
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * 워치리스트 조회
     */
    @GetMapping("/api/watchlist")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getWatchlist(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) Long groupId) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("success", false);
                response.put("message", "로그인이 필요합니다.");
                return ResponseEntity.status(401).body(response);
            }

            List<UserWatchlist> watchlist;
            if (groupId != null) {
                watchlist = watchlistService.getWatchlistByGroup(userId, groupId);
            } else {
                watchlist = watchlistService.getWatchlist(userId);
            }

            response.put("success", true);
            response.put("data", watchlist.stream().map(w -> {
                Map<String, Object> item = new HashMap<>();
                item.put("id", w.getId());
                item.put("symbol", w.getSymbol());
                item.put("groupId", w.getGroup() != null ? w.getGroup().getId() : null);
                item.put("groupName", w.getGroup() != null ? w.getGroup().getName() : null);
                item.put("createdAt", w.getCreatedAt());
                return item;
            }).toList());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("워치리스트 조회 실패", e);
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * 종목 좋아요 여부 확인
     */
    @GetMapping("/api/watchlist/check/{symbol}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> checkWatchlist(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String symbol) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("isInWatchlist", false);
                return ResponseEntity.ok(response);
            }

            boolean isInWatchlist = watchlistService.isInWatchlist(userId, symbol);
            response.put("isInWatchlist", isInWatchlist);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("워치리스트 확인 실패", e);
            response.put("isInWatchlist", false);
            return ResponseEntity.ok(response);
        }
    }

    /**
     * 종목 그룹 변경
     */
    @PostMapping("/api/watchlist/move")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> moveToGroup(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, Object> request) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("success", false);
                response.put("message", "로그인이 필요합니다.");
                return ResponseEntity.status(401).body(response);
            }

            String symbol = (String) request.get("symbol");
            Long groupId = request.get("groupId") != null ? 
                    Long.valueOf(request.get("groupId").toString()) : null;

            watchlistService.updateWatchlistGroup(userId, symbol, groupId);

            response.put("success", true);
            response.put("message", "그룹이 변경되었습니다.");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("그룹 변경 실패", e);
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // ========================================
    // 그룹 API
    // ========================================

    /**
     * 그룹 목록 조회
     */
    @GetMapping("/api/watchlist/groups")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getGroups(
            @AuthenticationPrincipal UserDetails userDetails) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("success", false);
                response.put("message", "로그인이 필요합니다.");
                return ResponseEntity.status(401).body(response);
            }

            List<WatchlistGroup> groups = watchlistService.getGroups(userId);

            response.put("success", true);
            response.put("data", groups.stream().map(g -> {
                Map<String, Object> item = new HashMap<>();
                item.put("id", g.getId());
                item.put("name", g.getName());
                item.put("color", g.getColor());
                item.put("createdAt", g.getCreatedAt());
                return item;
            }).toList());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("그룹 조회 실패", e);
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * 그룹 생성
     */
    @PostMapping("/api/watchlist/groups")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> createGroup(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, String> request) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("success", false);
                response.put("message", "로그인이 필요합니다.");
                return ResponseEntity.status(401).body(response);
            }

            String name = request.get("name");
            String color = request.get("color");

            if (name == null || name.trim().isEmpty()) {
                response.put("success", false);
                response.put("message", "그룹 이름이 필요합니다.");
                return ResponseEntity.badRequest().body(response);
            }

            WatchlistGroup group = watchlistService.createGroup(userId, name.trim(), color);

            response.put("success", true);
            response.put("message", "그룹이 생성되었습니다.");
            response.put("data", Map.of(
                    "id", group.getId(),
                    "name", group.getName(),
                    "color", group.getColor()
            ));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("그룹 생성 실패", e);
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * 그룹 수정
     */
    @PutMapping("/api/watchlist/groups/{groupId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> updateGroup(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long groupId,
            @RequestBody Map<String, String> request) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("success", false);
                response.put("message", "로그인이 필요합니다.");
                return ResponseEntity.status(401).body(response);
            }

            String name = request.get("name");
            String color = request.get("color");

            WatchlistGroup group = watchlistService.updateGroup(userId, groupId, name, color);

            response.put("success", true);
            response.put("message", "그룹이 수정되었습니다.");
            response.put("data", Map.of(
                    "id", group.getId(),
                    "name", group.getName(),
                    "color", group.getColor()
            ));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("그룹 수정 실패", e);
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * 그룹 삭제
     */
    @DeleteMapping("/api/watchlist/groups/{groupId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> deleteGroup(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long groupId) {

        Map<String, Object> response = new HashMap<>();

        try {
            Long userId = getUserId(userDetails);
            if (userId == null) {
                response.put("success", false);
                response.put("message", "로그인이 필요합니다.");
                return ResponseEntity.status(401).body(response);
            }

            watchlistService.deleteGroup(userId, groupId);

            response.put("success", true);
            response.put("message", "그룹이 삭제되었습니다.");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("그룹 삭제 실패", e);
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
}
