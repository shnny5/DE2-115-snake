module game_control(
   input clk_25MHz,
   input reset_n,
   input key_up,
   input key_down,
   input key_left,
   input key_right,
   input [9:0] pixel_x,
   input [9:0] pixel_y,
   input video_on,
   input p_tick,
   output reg [23:0] rgb_reg,
   output reg buzzer_signal,

   output reg [1:0] lcd_state,    
   output reg [31:0] game_timer,  
   output reg [6:0] score_out     
);

   // 游戏参数
   parameter MAX_LENGTH = 32;
   parameter GRID_SIZE = 20;
   parameter INIT_LENGTH = 3;
   parameter DISPLAY_BLOCKS = 32;
   parameter MAX_SCORE = 99;  // 最大分数
   
   // 蛇的位置
   reg [9:0] snake_x [0:MAX_LENGTH-1];
   reg [9:0] snake_y [0:MAX_LENGTH-1];
   reg [5:0] snake_length;
   reg [1:0] direction;
   reg [1:0] next_direction;
   
   // 食物位置
   reg [9:0] food_x;
   reg [9:0] food_y;
   
   // 帧率
   reg [3:0] update_counter;
   wire game_update;
   
   // 游戏状态
   reg game_over;
   reg game_started;
   
   // 计数器
   reg [5:0] i;
   
   // 颜色
   parameter BLACK = 24'h000000;
   parameter WHITE = 24'hFFFFFF;
   parameter RED = 24'hFF0000;
   parameter GREEN = 24'h00FF00;

   // 蜂鸣器
   reg [24:0] buzzer_counter;
   reg buzzer_done;  
   parameter BUZZER_DURATION = 25000000; // 1秒@25MHz
   
   // 真随机
   wire [15:0] random_num;
   lfsr_16bit random_gen(
       .clk(clk_25MHz),
       .reset_n(reset_n),
       .rand_num(random_num)
   );
   
   // 更新状态
   always @(posedge clk_25MHz or negedge reset_n)
   begin
       if(!reset_n)
           update_counter <= 4'b0;
       else if(p_tick)
           update_counter <= update_counter + 1'b1;
   end
   
   assign game_update = p_tick && (update_counter == 4'b0);

   always @(posedge clk_25MHz or negedge reset_n) begin
       if(!reset_n) begin
           game_timer <= 32'd0;
       end
       else if(!game_over && game_started) begin
           game_timer <= game_timer + 1'b1;
       end
   end
   
   // LCD 
   always @(posedge clk_25MHz or negedge reset_n) begin
       if(!reset_n) begin
           lcd_state <= 2'b00;    // 初始显示 Game Start
           game_started <= 1'b0;
       end
       else if(game_over) begin
           lcd_state <= 2'b01;    // Game over
           game_started <= 1'b0;
       end
       else if(!game_started && (key_up || key_down || key_left || key_right)) begin
           lcd_state <= 2'b00;    // Game start
           game_started <= 1'b1;
       end
       else if(game_started && !game_over) begin
           lcd_state <= 2'b00;    
       end
   end
   
   // 状态更新
   always @(posedge clk_25MHz or negedge reset_n)
   begin
       if(!reset_n) begin
           // 初始方向
           direction <= 2'b11;
           next_direction <= 2'b11;
           
           // 初始位置
           snake_x[0] <= 10'd320;
           snake_y[0] <= 10'd240;
           
           // 初始化分数
           score_out <= 0;
           
           for(i = 1; i < MAX_LENGTH; i = i + 1) begin
               snake_x[i] <= 0;
               snake_y[i] <= 0;
           end
           snake_length <= INIT_LENGTH;
           
           // 初始化游戏
           game_over <= 1'b0;     
           food_x <= 10'd400;
           food_y <= 10'd300;
           i <= 0;
           
           // 初始化蜂鸣器
           buzzer_counter <= 0;
           buzzer_signal <= 0;
           buzzer_done <= 0;
       end
       else begin
           // 游戏结束状态
           if(game_over) begin
               // 蜂鸣器控制
               if(!buzzer_done) begin
                   if(buzzer_counter < BUZZER_DURATION) begin
                       buzzer_counter <= buzzer_counter + 1;
                       buzzer_signal <= 1;
                   end
                   else begin
                       buzzer_signal <= 0;
                       buzzer_done <= 1;
                   end
               end
           end
           else begin
               // 方向更新
               if(game_update) begin
                   direction <= next_direction;
               end
               
               // 按键输入
               if(key_up && direction != 2'b01 && direction != 2'b00)
                   next_direction <= 2'b00;
               else if(key_down && direction != 2'b00 && direction != 2'b01)
                   next_direction <= 2'b01;
               else if(key_left && direction != 2'b11 && direction != 2'b10)
                   next_direction <= 2'b10;
               else if(key_right && direction != 2'b10 && direction != 2'b11)
                   next_direction <= 2'b11;
               
               // 更新游戏
               if(game_update) begin
                   // 移动蛇身
                   for(i = 0; i < MAX_LENGTH-1; i = i + 1) begin
                       if(i < snake_length-1) begin
                           snake_x[snake_length-1-i] <= snake_x[snake_length-2-i];
                           snake_y[snake_length-1-i] <= snake_y[snake_length-2-i];
                       end
                   end
                   
                   // 移动蛇头
                   case(direction)
                       2'b00: snake_y[0] <= snake_y[0] - GRID_SIZE;  // 上
                       2'b01: snake_y[0] <= snake_y[0] + GRID_SIZE;  // 下
                       2'b10: snake_x[0] <= snake_x[0] - GRID_SIZE;  // 左
                       2'b11: snake_x[0] <= snake_x[0] + GRID_SIZE;  // 右
                   endcase
                   
                   // 是否吃到食物
                   if((snake_x[0] == food_x) && (snake_y[0] == food_y)) begin
                       snake_length <= snake_length + 1'b1;
                       food_x <= ((random_num[7:0] * GRID_SIZE) % (680 - GRID_SIZE)) / GRID_SIZE * GRID_SIZE;
                       food_y <= ((random_num[15:8] * GRID_SIZE) % (480 - GRID_SIZE)) / GRID_SIZE * GRID_SIZE;
                       // 分数
                       if(score_out < MAX_SCORE)
                           score_out <= score_out + 1;
                   end
                   
                   // 游戏结束
                   if(snake_x[0] >= 680 || snake_x[0] < 0 ||
                      snake_y[0] >= 480 || snake_y[0] < 0) begin
                       game_over <= 1'b1;
                       buzzer_counter <= 0;
                       buzzer_done <= 0;
                   end
                   
                   // 是否撞到自己
                   for(i = 0; i < MAX_LENGTH; i = i + 1) begin
                       if(i > 0 && i < snake_length) begin
                           if((snake_x[0] == snake_x[i]) && (snake_y[0] == snake_y[i])) begin
                               game_over <= 1'b1;
                               buzzer_counter <= 0;
                               buzzer_done <= 0;
                           end
                       end
                   end
               end
           end
       end
   end
   
   // 显示控制
   reg in_food_area;
   reg [31:0] in_snake_area;
   reg [4:0] block_index;
   
   always @(*) begin
       // 检查是食物区域
       in_food_area = ((pixel_x >= food_x) && (pixel_x < food_x + GRID_SIZE) &&
                      (pixel_y >= food_y) && (pixel_y < food_y + GRID_SIZE));
       
       // 检查蛇的区域
       block_index = 0;
       in_snake_area = 0;
       
       for(i = 0; i < DISPLAY_BLOCKS; i = i + 1) begin
           if(i < snake_length) begin
               if((pixel_x >= snake_x[i]) && (pixel_x < snake_x[i] + GRID_SIZE) &&
                  (pixel_y >= snake_y[i]) && (pixel_y < snake_y[i] + GRID_SIZE)) begin
                   in_snake_area[i] = 1;
                   block_index = i;
               end
           end
       end
       
       // 颜色
       if(!video_on)
           rgb_reg = BLACK;
       else if(game_over)
           rgb_reg = RED;
       else if(in_food_area)
           rgb_reg = RED;
       else if(|in_snake_area)
           rgb_reg = (block_index == 0) ? WHITE : GREEN;
       else
           rgb_reg = BLACK;
   end

endmodule