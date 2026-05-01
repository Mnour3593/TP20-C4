`timescale 1ns / 1ps

module tb_counter;

    // Sayaca göndereceğimiz sahte girişler (reg)
    reg clk;
    reg reset;
    reg tick;
    reg load;
    reg count_down;
    reg count_up;

    // Sayaçtan okuyacağımız çıkışlar (wire)
    wire [3:0] digit3, digit2, digit1, digit0;
    wire at_zero, at_maximum;

    // Test edeceğimiz senin yazdığın yeni modülü çağırıyoruz (UUT - Unit Under Test)
    universal_counter uut (
        .clk(clk), .reset(reset), .tick(tick), .load(load),
        .count_down(count_down), .count_up(count_up),
        .digit3(digit3), .digit2(digit2), .digit1(digit1), .digit0(digit0),
        .at_zero(at_zero), .at_maximum(at_maximum)
    );

    // Saat (Clock) Sinyali Üretici (Sürekli 0 ve 1 arasında gidip gelir)
    always #5 clk = ~clk;

    // Test Senaryosu
    initial begin
        // GTKWave gibi programlarda dalga formunu görmek istersen diye:
        $dumpfile("test_sonucu.vcd");
        $dumpvars(0, tb_counter);

        // 1. BAŞLANGIÇ: Her şeyi sıfırla, reset at
        clk = 0; reset = 1; tick = 0; load = 0; count_down = 0; count_up = 0;
        
        // Ekrana başlık yazdırıyoruz
        $display("Zaman | D3 D2 : D1 D0 | Sifir_Alarmi | Max_Alarmi");
        $monitor("%5t |  %d  %d :  %d  %d |      %b       |     %b", 
                 $time, digit3, digit2, digit1, digit0, at_zero, at_maximum);

        // Biraz bekle ve reseti kaldır
        #15 reset = 0;

        // 2. GERİ SAYIM TESTİ
        count_down = 1; // Geri sayma modunu aç
        
        // 5 kere tick sinyali gönder (Sanki 5 salise geçmiş gibi)
        repeat (5) begin
            #10 tick = 1; // Tick'i 1 yap
            #10 tick = 0; // Tick'i geri 0 yap (pulse etkisi)
        end

        // 3. İLERİ SAYIM TESTİ (İstersen buraya count_up=1 yapıp onu da deneyebilirsin)
        
        // Testi bitir
        #50 $finish;
    end

endmodule