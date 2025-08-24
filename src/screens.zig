const rl = @import("raylib");
const std = @import("std");
const Game = @import("game.zig").Game;

const ScreenType = enum {
    Menu,
    Playing,
    GameOver,
    HighScore,
};

pub const Screens = struct {
    allocator: std.mem.Allocator,
    current: ScreenType,
    high_score: usize,
    last_score: usize,

    pub fn init(allocator: std.mem.Allocator) Screens {
        return Screens{
            .allocator = allocator,
            .current = .Menu,
            .high_score = 0,
            .last_score = 0,
        };
    }

    pub fn drawCenteredText(comptime fmt: []const u8, args: anytype, y: i32, fontSize: i32, color: rl.Color) void {
        var buffer: [256]u8 = undefined;
        const text: [:0]const u8 = std.fmt.bufPrintZ(&buffer, fmt, args) catch return;
        const textWidth: i32 = rl.measureText(text, fontSize);
        const screenWidth: i32 = rl.getScreenWidth();
        const x: i32 = @divTrunc(screenWidth - textWidth, 2);
        rl.drawText(text, x, y, fontSize, color);
    }

    pub fn drawMenu(_: *Screens) void {
        rl.clearBackground(rl.Color.black);

        const screenWidth: i32 = rl.getScreenWidth();
        const screenHeight: i32 = rl.getScreenHeight();

        const btnWidth: i32 = @divTrunc(screenWidth, 4);
        const btnHeight: i32 = 50;
        const startY: i32 = @divTrunc(screenHeight, 2) - 100;
        const btnX: i32 = @divTrunc(screenWidth - btnWidth, 2);

        drawCenteredText("Snake Game", .{}, startY - 100, 40, rl.Color.green);

        rl.drawRectangle(btnX, startY, btnWidth, btnHeight, rl.Color.dark_green);
        drawCenteredText("Start Game", .{}, startY + @divTrunc(btnHeight - 20, 2), 20, rl.Color.white);

        rl.drawRectangle(btnX, startY + 70, btnWidth, btnHeight, rl.Color.dark_blue);
        drawCenteredText("Highest Score", .{}, startY + 70 + @divTrunc(btnHeight - 20, 2), 20, rl.Color.white);

        rl.drawRectangle(btnX, startY + 140, btnWidth, btnHeight, rl.Color.red);
        drawCenteredText("Quit", .{}, startY + 140 + @divTrunc(btnHeight - 20, 2), 20, rl.Color.white);
    }

    pub fn updateMenu(self: *Screens, game_ptr: *?*Game, w: i16, h: i16) !void {
        const screenWidth: i32 = rl.getScreenWidth();
        const screenHeight: i32 = rl.getScreenHeight();

        const btnWidth: i32 = @divTrunc(screenWidth, 4);
        const btnHeight: i32 = 50;
        const startY: i32 = @divTrunc(screenHeight, 2) - 100;
        const btnX: i32 = @divTrunc(screenWidth - btnWidth, 2);

        const mousePos = rl.getMousePosition();

        const startBtn = rl.Rectangle{
            .x = @floatFromInt(btnX),
            .y = @floatFromInt(startY),
            .width = @floatFromInt(btnWidth),
            .height = @floatFromInt(btnHeight),
        };
        const scoreBtn = rl.Rectangle{
            .x = @floatFromInt(btnX),
            .y = @floatFromInt(startY + 70),
            .width = @floatFromInt(btnWidth),
            .height = @floatFromInt(btnHeight),
        };
        const quitBtn = rl.Rectangle{
            .x = @floatFromInt(btnX),
            .y = @floatFromInt(startY + 140),
            .width = @floatFromInt(btnWidth),
            .height = @floatFromInt(btnHeight),
        };

        if (rl.isMouseButtonPressed(.left)) {
            if (rl.checkCollisionPointRec(mousePos, startBtn)) {
                game_ptr.* = try Game.init(self.allocator, w, h);
                self.last_score = 0;
                self.current = .Playing;
            } else if (rl.checkCollisionPointRec(mousePos, scoreBtn)) {
                self.current = .HighScore;
            } else if (rl.checkCollisionPointRec(mousePos, quitBtn)) {
                rl.closeWindow();
                std.process.exit(0);
            }
        }
    }

    pub fn drawPlaying(_: *Screens, game: *Game, cellsize: i16) void {
        rl.clearBackground(rl.Color.black);

        const half_cell: i16 = @divTrunc(cellsize, 2);

        // Draw food
        const cx: i32 = @as(i32, game.food.x) * @as(i32, cellsize) + @as(i32, half_cell);
        const cy: i32 = @as(i32, game.food.y) * @as(i32, cellsize) + @as(i32, half_cell);
        rl.drawCircle(cx, cy, @floatFromInt(@as(i32, half_cell)), rl.Color.red);

        // Draw snake
        for (game.snake.items) |it| {
            const sx: i32 = @as(i32, it.x) * @as(i32, cellsize);
            const sy: i32 = @as(i32, it.y) * @as(i32, cellsize);
            rl.drawRectangle(sx, sy, @as(i32, cellsize), @as(i32, cellsize), rl.Color.green);
        }
    }

    pub fn drawGameOver(self: *Screens, game_ptr: *?*Game) void {
        rl.clearBackground(rl.Color.black);
        drawCenteredText("Game Over", .{}, @divTrunc(rl.getScreenHeight(), 2) - 80, 40, rl.Color.red);
        drawCenteredText("Your Score: {}", .{game_ptr.*.?.score}, @divTrunc(rl.getScreenHeight(), 2) - 20, 25, rl.Color.white);
        drawCenteredText("Highest Score: {}", .{self.high_score}, @divTrunc(rl.getScreenHeight(), 2) + 20, 25, rl.Color.yellow);
        drawCenteredText("Press ENTER to return to menu", .{}, @divTrunc(rl.getScreenHeight(), 2) + 70, 20, rl.Color.gray);
    }

    pub fn updateGameOver(self: *Screens, game_ptr: *?*Game) void {
        if (rl.isKeyPressed(.enter)) {
            if (game_ptr.*) |g| {
                g.deinit();
                game_ptr.* = null;
            }
            self.current = .Menu;
        }
    }

    pub fn drawHighScore(self: *Screens) void {
        rl.clearBackground(rl.Color.black);
        drawCenteredText("Highest Score So Far: {}", .{self.high_score}, @divTrunc(rl.getScreenHeight(), 2) - 20, 30, rl.Color.white);
        drawCenteredText("Click anywhere to go back", .{}, @divTrunc(rl.getScreenHeight(), 2) + 30, 20, rl.Color.gray);
    }

    pub fn updateHighScore(self: *Screens) void {
        if (rl.isMouseButtonPressed(.left)) {
            self.current = .Menu;
        }
    }
};
