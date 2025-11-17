#pragma once

#include <array>
#include <vector>
#include <string>
#include <string_view>
#include <algorithm>
#include <utility>
#include <cstring>

struct NameEntry {
    std::array<char, 32> name;  // Fixed-size string buffer

    // Helper to set the name safely
    void set_name(const char* _name) {
        std::strncpy(name.data(), _name, name.size() - 1);
        name[name.size() - 1] = '\0';  // Ensure null termination
    }

    // Helper to get as string_view (C++17)
    std::string_view get_name() const {
        return std::string_view(name.data());
    }
};

// Search for a name in the array and return its index
// Returns -1 if not found
template<size_t N>
int get_name_index(const std::array<NameEntry, N>& names, std::string_view search_name) {
    for (size_t i = 0; i < N; i++) {
        if (names[i].get_name() == search_name) {
            return static_cast<int>(i);
        }
    }
    return -1;  // Not found
}

// Calculate karma score for a person
// Formula: (cleanings * 10) - (coffees * 0.5)
// This rewards cleaning heavily and slightly penalizes consumption
inline float calculate_karma(uint32_t coffees, uint32_t cleanings) {
    return (static_cast<float>(cleanings) * 10.0f) - (static_cast<float>(coffees) * 0.5f);
}

// Generate complete report with header, leaderboard, and footer
template<size_t N>
std::vector<uint8_t> generate_report(const std::string& title, int total_count, const std::string& unit,
                                      const std::array<NameEntry, N>& names,
                                      const std::array<uint32_t, N>& data,
                                      const std::array<uint32_t, N>& cleanings,
                                      int total_names) {
    std::vector<uint8_t> escpos_data;

    // ESC @ - Initialize printer
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x40);

    // Feed one line
    escpos_data.push_back('\n');

    // ESC a 1 - Center align
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x61);
    escpos_data.push_back(0x01);

    // ESC E 1 - Bold on
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x45);
    escpos_data.push_back(0x01);

    std::string header = "=== " + title + " ===\n";
    escpos_data.insert(escpos_data.end(), header.begin(), header.end());

    // ESC E 0 - Bold off
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x45);
    escpos_data.push_back(0x00);

    // ESC a 0 - Left align
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x61);
    escpos_data.push_back(0x00);

    std::string total_line = "Total: " + std::to_string(total_count) + " " + unit + "\n";
    escpos_data.insert(escpos_data.end(), total_line.begin(), total_line.end());

    std::string scope_line = "Leaderboard:\n\n";
    escpos_data.insert(escpos_data.end(), scope_line.begin(), scope_line.end());

    // Build leaderboard from names and counts with karma
    struct LeaderboardEntry {
        std::string name;
        uint32_t count;
        float karma;
    };
    std::vector<LeaderboardEntry> leaderboard;

    for (int i = 0; i < total_names; i++) {
        std::string name(names[i].get_name());
        if (!name.empty() && data[i] > 0) {
            float karma = calculate_karma(data[i], cleanings[i]);
            leaderboard.push_back({name, data[i], karma});
        }
    }

    // Sort by count (descending) to create leaderboard
    std::sort(leaderboard.begin(), leaderboard.end(),
        [](const auto& a, const auto& b) { return a.count > b.count; });

    // Build complete leaderboard
    int rank = 1;
    for (const auto& entry : leaderboard) {
        std::string line = std::to_string(rank) + ". " + entry.name + ": " + std::to_string(entry.count);
        escpos_data.insert(escpos_data.end(), line.begin(), line.end());

        // Add karma score
        char karma_buffer[20];
        snprintf(karma_buffer, sizeof(karma_buffer), " (Karma: %.1f)", entry.karma);
        std::string karma_str(karma_buffer);
        escpos_data.insert(escpos_data.end(), karma_str.begin(), karma_str.end());

        escpos_data.push_back('\n');
        rank++;
    }

    // ESC a 1 - Center align
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x61);
    escpos_data.push_back(0x01);

    std::string footer = "\n--- End Report ---\n\n";
    escpos_data.insert(escpos_data.end(), footer.begin(), footer.end());

    // ESC a 0 - Left align
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x61);
    escpos_data.push_back(0x00);

    // ESC d 3 - Feed 1 line
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x64);
    escpos_data.push_back(0x01);

    return escpos_data;
}

// Generate report with timestamps for cleanings
template<size_t N>
std::vector<uint8_t> generate_cleaning_report(const std::string& title, int total_count, const std::string& unit,
                                               const std::array<NameEntry, N>& names,
                                               const std::array<uint32_t, N>& data,
                                               const std::array<uint32_t, N>& consumptions,
                                               const std::array<esphome::ESPTime, N>& times,
                                               int total_names) {
    std::vector<uint8_t> escpos_data;

    // ESC @ - Initialize printer
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x40);

    // Feed one line
    escpos_data.push_back('\n');

    // ESC a 1 - Center align
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x61);
    escpos_data.push_back(0x01);

    // ESC E 1 - Bold on
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x45);
    escpos_data.push_back(0x01);

    std::string header = "=== " + title + " ===\n";
    escpos_data.insert(escpos_data.end(), header.begin(), header.end());

    // ESC E 0 - Bold off
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x45);
    escpos_data.push_back(0x00);

    // ESC a 0 - Left align
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x61);
    escpos_data.push_back(0x00);

    std::string total_line = "Total: " + std::to_string(total_count) + " " + unit + "\n";
    escpos_data.insert(escpos_data.end(), total_line.begin(), total_line.end());

    std::string scope_line = "Leaderboard:\n\n";
    escpos_data.insert(escpos_data.end(), scope_line.begin(), scope_line.end());

    // Build leaderboard from names, counts, times, and karma
    struct LeaderboardEntry {
        std::string name;
        uint32_t count;
        esphome::ESPTime time;
        float karma;
    };
    std::vector<LeaderboardEntry> leaderboard;

    for (int i = 0; i < total_names; i++) {
        std::string name(names[i].get_name());
        if (!name.empty() && data[i] > 0) {
            float karma = calculate_karma(consumptions[i], data[i]);
            leaderboard.push_back({name, data[i], times[i], karma});
        }
    }

    // Sort by count (descending) to create leaderboard
    std::sort(leaderboard.begin(), leaderboard.end(),
        [](const auto& a, const auto& b) { return a.count > b.count; });

    // Build complete leaderboard with timestamps
    int rank = 1;
    for (auto& entry : leaderboard) {
        std::string line = std::to_string(rank) + ". " + entry.name + ": " + std::to_string(entry.count);
        escpos_data.insert(escpos_data.end(), line.begin(), line.end());

        // Add karma score
        char karma_buffer[20];
        snprintf(karma_buffer, sizeof(karma_buffer), " (Karma: %.1f)", entry.karma);
        std::string karma_str(karma_buffer);
        escpos_data.insert(escpos_data.end(), karma_str.begin(), karma_str.end());

        // Add last cleaning time if available
        if (entry.time.is_valid()) {
            std::string time_str = entry.time.strftime("\n   Zuletzt: %d.%m.%Y %H:%M");
            escpos_data.insert(escpos_data.end(), time_str.begin(), time_str.end());
        }

        escpos_data.push_back('\n');
        rank++;
    }

    // ESC a 1 - Center align
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x61);
    escpos_data.push_back(0x01);

    std::string footer = "\n--- End Report ---\n\n";
    escpos_data.insert(escpos_data.end(), footer.begin(), footer.end());

    // ESC a 0 - Left align
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x61);
    escpos_data.push_back(0x00);

    // ESC d 3 - Feed 1 line
    escpos_data.push_back(0x1B);
    escpos_data.push_back(0x64);
    escpos_data.push_back(0x01);

    return escpos_data;
}
