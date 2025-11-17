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

// Generate complete report with header, leaderboard, and footer
template<size_t N>
std::vector<uint8_t> generate_report(const std::string& title, int total_count, const std::string& unit,
                                      const std::array<NameEntry, N>& names, const std::array<uint32_t, N>& data, int total_names) {
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

    // Build leaderboard from names and counts
    std::vector<std::pair<std::string, uint32_t>> leaderboard;

    for (int i = 0; i < total_names; i++) {
        std::string name(names[i].get_name());
        if (!name.empty() && data[i] > 0) {
            leaderboard.push_back({name, data[i]});
        }
    }

    // Sort by count (descending) to create leaderboard
    std::sort(leaderboard.begin(), leaderboard.end(),
        [](const auto& a, const auto& b) { return a.second > b.second; });

    // Build complete leaderboard
    int rank = 1;
    for (const auto& entry : leaderboard) {
        std::string line = std::to_string(rank) + ". " + entry.first + ": " + std::to_string(entry.second) + "\n";

        escpos_data.insert(escpos_data.end(), line.begin(), line.end());
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
                                               const std::array<NameEntry, N>& names, const std::array<uint32_t, N>& data,
                                               const std::array<esphome::ESPTime, N>& times, int total_names) {
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

    // Build leaderboard from names, counts, and times
    std::vector<std::tuple<std::string, uint32_t, esphome::ESPTime>> leaderboard;

    for (int i = 0; i < total_names; i++) {
        std::string name(names[i].get_name());
        if (!name.empty() && data[i] > 0) {
            leaderboard.push_back({name, data[i], times[i]});
        }
    }

    // Sort by count (descending) to create leaderboard
    std::sort(leaderboard.begin(), leaderboard.end(),
        [](const auto& a, const auto& b) { return std::get<1>(a) > std::get<1>(b); });

    // Build complete leaderboard with timestamps
    int rank = 1;
    for (auto& entry : leaderboard) {
        std::string line = std::to_string(rank) + ". " + std::get<0>(entry) + ": " + std::to_string(std::get<1>(entry));
        escpos_data.insert(escpos_data.end(), line.begin(), line.end());

        // Add last cleaning time if available
        esphome::ESPTime time_copy = std::get<2>(entry);
        if (time_copy.is_valid()) {
            std::string time_str = time_copy.strftime("\n   Zuletzt: %d.%m.%Y %H:%M");
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
