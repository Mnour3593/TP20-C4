`timescale 1ns / 1ps

module tb_sequence_detector;

    reg clk;
    reg reset;
    reg bit_in;
    reg bit_valid;

    wire sequence_matched;
    wire [2:0] progress;

    sequence_detector uut (
        .clk(clk),
        .reset(reset),
        .bit_in(bit_in),
        .bit_valid(bit_valid),
        .sequence_matched(sequence_matched),
        .progress(progress)
    );

    // Saat sinyali
    always #5 clk = ~clk;

    initial begin
        // 1. BAŞLANGIÇ VE RESET DURUMU
        clk = 0; reset = 1; bit_in = 0; bit_valid = 0;
        #10 reset = 0;

        // 2. NORMAL EŞLEŞME (1011)
        #10 bit_valid = 1; bit_in = 1; 
        #10 bit_in = 0;                
        #10 bit_in = 1;                
        #10 bit_in = 1; // -> BURADA sequence_matched = 1 OLMALI
        
        // 3. YANLIŞ DİZİLİM TESTİ (1010)
        #10 bit_in = 1; // S1
        #10 bit_in = 0; // S2
        #10 bit_in = 1; // S3
        #10 bit_in = 0; // Hatalı bit! S2'ye (10 durumuna) geri dönmeli.
        
        // 4. BİT GEÇERSİZ (PAUSE) TESTİ
        // Şu an sistem S2'de. bit_valid'i 0 yapıp 20ns bekliyoruz.
        #10 bit_valid = 0; bit_in = 1; // Bu '1'i görmezden gelmeli.
        #20; 
        
        // 5. PAUSE SONRASI DEVAM VE ÖRTÜŞME (OVERLAPPING) TESTİ
        #10 bit_valid = 1; bit_in = 1; // Kaldığı yerden (S2'den) devam edip S3'e geçmeli
        #10 bit_in = 1; // -> BURADA İKİNCİ sequence_matched = 1 OLMALI (1011 tamamlandı)
        
        // 6. DİZİ ORTASINDA ASENKRON RESET TESTİ
        #10 bit_in = 1; 
        #10 bit_in = 0; 
        #5  reset = 1;  // Dizi ortasında aniden reset geldi!
        #10 reset = 0;  // Sistem tamamen sıfırlanmış olmalı.

        #20 $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_sequence_detector);
    end

endmodule