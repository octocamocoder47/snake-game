const std = @import("std");
const rl = @import("raylib");
const ArrayList = std.ArrayList;
const print = std.debug.print;
const globals = @import("game.zig");
const Game = globals.Game;
const Screens = @import("screens.zig").Screens;

// const print = std.debug.print;

pub fn main() !void {
    const w = globals.screenWidth / globals.cellsize;
    const h = globals.screenHeight / globals.cellsize;

    rl.initWindow(globals.screenWidth, globals.screenHeight, "Snake Game");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var screens = Screens.init();
    var game: ?*Game = null;

    var previoustime = std.time.nanoTimestamp();
    var pause = false;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        switch (screens.current) {
            .Menu => {
                screens.drawMenu();
                try screens.updateMenu(&game, w, h);
            },
            .Playing => {
                if (game) |g| {
                    // Pause toggle
                    if (rl.isKeyPressed(.p)) {
                        pause = !pause;
                    }

                    if (!pause) {
                        // Handle movement input
                        g.input();

                        // Frame timing
                        const now = std.time.nanoTimestamp();
                        if (now - previoustime >= globals.frametime) {
                            previoustime = now;
                            try g.move();
                        }

                        rl.clearBackground(rl.Color.black);
                        screens.drawPlaying(g, globals.cellsize);

                        // Collision check -> game over
                        if (g.collisionDetection()) {
                            if (g.snake.items.len > screens.high_score) {
                                screens.high_score = g.snake.items.len;
                            }
                            screens.current = .GameOver;
                        }
                    } else {
                        // Optional: show pause overlay
                        drawPauseOverlay();
                    }
                }
            },
            .GameOver => {
                screens.drawGameOver(&game);
                screens.updateGameOver(&game);
            },
            .HighScore => { screens.drawHighScore(); screens.updateHighScore(); },
        }

        rl.endDrawing();
    }
}

fn drawPauseOverlay() void {
    Screens.drawCenteredText("Paused", .{}, @divTrunc(rl.getScreenHeight(), 2), 30, rl.Color.yellow);
}



pub fn main2() !void {
    const w = globals.screenWidth / globals.cellsize;
    const h = globals.screenHeight / globals.cellsize;

    rl.initWindow(globals.screenWidth, globals.screenHeight, "Snake Game");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var screens = Screens.init();
    var game: ?*Game = null;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        switch (screens.current) {
            .Menu => {
                screens.drawMenu();
                try screens.updateMenu(&game, w, h);
            },
            .Playing => {
                if (game) |g| {
                    screens.drawPlaying(g, globals.cellsize);
                    try screens.updatePlaying(g);
                }
            },
            .GameOver => {
                screens.drawGameOver();
                screens.updateGameOver(&game);
            },
        }

        rl.endDrawing();
    }
}


pub fn main3() !void {
    rl.initWindow(globals.screenWidth, globals.screenHeight, "Snake Game");
    defer rl.closeWindow();
    // rl.setWindowPosition(100, 100);
    rl.setTargetFPS(60);

    const w = globals.screenWidth / globals.cellsize;
    const h = globals.screenHeight / globals.cellsize;

    var game = Game.init(std.heap.page_allocator, w, h) catch {
        std.debug.print("Failed to initialize game\n", .{});
        return;
    };

    defer game.deinit();
    var previoustime = std.time.nanoTimestamp();
    var pause = false;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        if (rl.isKeyDown(.q)) break;
        if(rl.isKeyPressed(.p)) {
            pause = !pause;
            continue;
        }

        if(!pause) {
            game.input();
            const now = std.time.nanoTimestamp();
            if (now - previoustime >= globals.frametime) {
                previoustime = now;
                try game.move();
            }

            rl.clearBackground(rl.Color.black);
            game.draw();
            if (game.collisionDetection()) break;

        }
    }
}

//     print("****************************\n", .{});
//     print("Your final point is {}\n", .{game.snake.items.len - 1});
//     print("****************************\n", .{});
// }
