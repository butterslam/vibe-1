//
//  HomeView.swift
//  vibe 1
//
//  Created by Jamie Cheatham on 10/4/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var habitStore: HabitStore
    @State private var currentQuote: String = ""
    @State private var currentAuthor: String = ""
    
    private let motivationalQuotes = [
        ("The secret of getting ahead is getting started.", "Mark Twain"),
        ("Success is not final, failure is not fatal: it is the courage to continue that counts.", "Winston Churchill"),
        ("The way to get started is to quit talking and begin doing.", "Walt Disney"),
        ("Don't be pushed around by the fears in your mind. Be led by the dreams in your heart.", "Roy T. Bennett"),
        ("The future belongs to those who believe in the beauty of their dreams.", "Eleanor Roosevelt"),
        ("It is during our darkest moments that we must focus to see the light.", "Aristotle"),
        ("The only way to do great work is to love what you do.", "Steve Jobs"),
        ("Believe you can and you're halfway there.", "Theodore Roosevelt"),
        ("Your limitation—it's only your imagination.", "Unknown"),
        ("Push yourself, because no one else is going to do it for you.", "Unknown"),
        ("Sometimes later becomes never. Do it now.", "Unknown"),
        ("Great things never come from comfort zones.", "Unknown"),
        ("Dream it. Wish it. Do it.", "Unknown"),
        ("Success doesn't just find you. You have to go out and get it.", "Unknown"),
        ("The harder you work for something, the greater you'll feel when you achieve it.", "Unknown"),
        ("Dream bigger. Do bigger.", "Unknown"),
        ("Don't stop when you're tired. Stop when you're done.", "Unknown"),
        ("Wake up with determination. Go to bed with satisfaction.", "Unknown"),
        ("Do something today that your future self will thank you for.", "Unknown"),
        ("Little things make big days.", "Unknown"),
        ("It's going to be hard, but hard does not mean impossible.", "Unknown"),
        ("Don't wait for opportunity. Create it.", "Unknown"),
        ("Sometimes we're tested not to show our weaknesses, but to discover our strengths.", "Unknown"),
        ("The key to success is to focus on goals, not obstacles.", "Unknown")
    ]
    
    var todayHabits: [Habit] {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let todayName = formatter.string(from: today)
        
        return habitStore.habits.filter { habit in
            habit.selectedDays.contains(todayName)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top section with date and quote
                VStack(spacing: 20) {
                    // Today's date
                    VStack(spacing: 8) {
                        Text("Today")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(getFormattedDate())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    
                    // Motivational quote
                    VStack(spacing: 12) {
                        Text(currentQuote)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        if !currentAuthor.isEmpty {
                            Text("— \(currentAuthor)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Today's habits section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Today's Habits")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    if todayHabits.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No habits for today")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("Add some habits to get started!")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(todayHabits) { habit in
                                    TodayHabitCard(habit: habit, habitStore: habitStore)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadRandomQuote()
        }
    }
    
    private func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private func loadRandomQuote() {
        let randomQuote = motivationalQuotes.randomElement() ?? ("Start your day with purpose.", "")
        currentQuote = randomQuote.0
        currentAuthor = randomQuote.1
    }
}

struct TodayHabitCard: View {
    let habit: Habit
    let habitStore: HabitStore
    @State private var showingEditSheet = false
    
    private func formatTime(_ date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return timeFormatter.string(from: date)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Completion button
            CompletionButton(habit: habit) {
                habitStore.toggleHabitCompletion(habit)
            }
            .alignmentGuide(VerticalAlignment.center) { d in
                d[VerticalAlignment.center] - 8 // Adjust to align button (not text below) with habit name
            }
            .frame(width: 40) // Fixed width to prevent lateral movement
            
            // Habit details - tappable area
            Button(action: {
                showingEditSheet = true
            }) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("\(formatTime(habit.timeOfDay)) • \(habit.frequencyPerWeek)x per week")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: habit, habitStore: habitStore)
        }
    }
}

#Preview {
    HomeView(habitStore: HabitStore())
}
