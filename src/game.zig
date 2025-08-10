const std = @import("std");
const rl = @import("raylib");
const ArrayList = std.ArrayList;

pub const screenWidth = 640 * 2;
pub const screenHeight = 360 * 2;
pub const cellsize: i16 = 20;
pub const frametime: u64 = 200_000_000;

const Vector = struct {
    x: i16 = 1,
    y: i16 = 0,

    pub fn setValues(self: *Vector,x: i16, y: i16) void {
        self.x = x;
        self.y = y;
        return;
    }

    pub fn isEquals(self: *Vector, x: i16, y: i16) bool {
        return self.x == x and self.y == y;
    }
};

pub const Game = struct {
    // const Self = @This();
    direction: Vector = Vector{},
    snake: ArrayList(Vector),
    food: Vector = Vector{},
    W: i16,
    H: i16,
    score:i16 = 0,

    pub fn init(allocator: std.mem.Allocator, W: i16, H:i16) !*Game {
        const game = try allocator.create(Game);
        game.* = Game {
            .W = W,
            .H = H,
            .snake = ArrayList(Vector).init(allocator)
        };

        try game.snake.append(Vector{ .x = 20, .y = 15 });
        game.freshFood();

        return game;
    }

    pub fn move(self: *Game) !void {
        var i = self.snake.items.len - 1;
        const tail = Vector{.x = self.snake.items[i].x, .y = self.snake.items[i].y};
        while(i > 0):(i -= 1) {
            self.snake.items[i].x = self.snake.items[i-1].x;
            self.snake.items[i].y = self.snake.items[i-1].y;
        }
        self.snake.items[0].x += self.direction.x;
        self.snake.items[0].y += self.direction.y;

        if(self.snake.items[0].x == self.food.x and self.snake.items[0].y == self.food.y) {
            self.score += 1;
            try self.snake.append(tail);
            self.freshFood();
        }

        return;
    }

    pub fn freshFood(self: *Game) void {
        const seed: u64 = @intCast(std.time.nanoTimestamp());
        var prng = std.Random.DefaultPrng.init(seed);
        var rng = prng.random();
        self.food.x = rng.intRangeAtMost(i16, 0, self.W - 1);
        self.food.y = rng.intRangeAtMost(i16, 0, self.H - 1);
    }

    pub fn collisionDetection(self: *Game) bool {
        const head = self.snake.items[0];
        const items = self.snake.items;

        for(items[1..]) |it| {
            if(it.x == head.x and it.y == head.y) {
                return true;
            }
        }

        if(head.x < 0 or head.x >= self.W or head.y < 0 or head.y >= self.H) {
            return true;
        }

        return false;
    }

    pub fn draw_score(self: *Game) void {
        var buffer: [32]u8 = undefined;
        const text: [:0]const u8 = std.fmt.bufPrintZ(&buffer, "Score: {}", .{self.score}) catch |err| {
            std.debug.print("{}", .{err});
            return;
        };
        rl.drawText(text, 10, 10, 20, rl.Color.white);
    }

    pub fn draw(self: *Game) void {
        self.draw_score();
        rl.drawCircle(@intCast(self.food.x * cellsize + cellsize / 2),
            @intCast(self.food.y * cellsize + cellsize / 2),
            @floatFromInt(cellsize / 2),
            rl.Color.red);

        for (self.snake.items) |it| {
            rl.drawRectangle(@intCast(it.x * cellsize),
            @intCast(it.y * cellsize),
            @intCast(cellsize),
            @intCast(cellsize),
            rl.Color.green);
        }
    }

    pub fn input(self: *Game) void {
        if(rl.isKeyDown(.w) or rl.isKeyDown(.up)) {
            if(self.direction.isEquals(0, 1)) {
                return;
            }
            self.direction.setValues(0, -1);
        }
        if(rl.isKeyDown(.a) or rl.isKeyDown(.left)) {
            if(self.direction.isEquals(1, 0)) {
                return;
            }
            self.direction.setValues(-1, 0);
        }
        if(rl.isKeyDown(.s) or rl.isKeyDown(.down)) {
            if(self.direction.isEquals(0, -1)) {
                return;
            }
            self.direction.setValues(0, 1);
        }
        if(rl.isKeyDown(.d) or rl.isKeyDown(.right)) {
            if(self.direction.isEquals(-1, 0)) {
                return;
            }
            self.direction.setValues(1, 0);
        }
        return;
    }

    pub fn deinit(self: *Game) void {
        self.snake.deinit();
    }
};
