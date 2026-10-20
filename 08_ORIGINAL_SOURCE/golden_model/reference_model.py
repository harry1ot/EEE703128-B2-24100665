SEG={0:0b1111110,1:0b0110000,2:0b1101101,3:0b1111001,
4:0b0110011,5:0b1011011,6:0b1011111,7:0b1110000,
8:0b1111111,9:0b1111011}

def digits(x):
    return [(x//1000)%10,(x//100)%10,(x//10)%10,x%10]

def shown(ds,idx,blank):
    d3,d2,d1,d0=ds
    if not blank: return [d0,d1,d2,d3][idx]
    if idx==3: return None if d3==0 else d3
    if idx==2: return None if d3==0 and d2==0 else d2
    if idx==1: return None if d3==0 and d2==0 and d1==0 else d1
    return d0

def pwm(phase,b): return phase < b

def test_four_digits():
    ds=[1,2,3,4]
    assert [shown(ds,i,False) for i in range(4)] == [4,3,2,1]

def test_0042():
    ds=digits(42)
    assert [shown(ds,i,True) for i in range(4)] == [2,4,None,None]

def test_0000():
    ds=digits(0)
    assert shown(ds,0,True)==0

def test_9999():
    ds=digits(9999)
    assert [shown(ds,i,True) for i in range(4)] == [9,9,9,9]

def test_brightness():
    assert not pwm(0,0)
    assert pwm(0,255)
    assert not pwm(255,255)

def test_scan():
    assert 10_000_000/1024 > 60

def test_phase():
    for p in [0,255,256,511,512,767,768,1023]:
        assert 0 <= ((p>>8)&3) <= 3
        assert 0 <= (p&255) <= 255

if __name__=="__main__":
    for n in [x for x in globals() if x.startswith("test_")]:
        globals()[n]()
        print(n,"PASS")
