Public Class Form1
    Dim myPort As Array  'COM Ports detected on the system will be stored here

    Dim mystring As String
    Dim q As New Queue
    Dim strSend As String              'String variable to store NewLine 
    Dim comPORT As String
    Dim receivedData As String = ""


    Delegate Sub DataDelegate(ByVal sdata As String)
    Private Sub Button1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)
        SerialPort1.Write("1")


    End Sub

    Private Sub Button2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)
        SerialPort1.Write("2")

    End Sub

    Private Sub Button3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button3.Click
        ' Start the timer.
        Timer1.Enabled = True
        Try
            SerialPort1.Open() 'Open to port'

            Button4.Enabled = True
            Button3.Enabled = False


            TextBox4.Text = "Connected..."
            TextBox5.Text = "Motor:Stop.."

        Catch ex As Exception
            Console.WriteLine(ex.Message)
            MsgBox("Com.Port Not Found", MsgBoxStyle.Exclamation)
        End Try
    End Sub

    Private Sub Button4_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button4.Click
        Button3.Enabled = True
        Button4.Enabled = False

        TextBox4.Text = "Disconnected"
        SerialPort1.Close()
    End Sub

    Private Sub SerialPort1_DataReceived(ByVal sender As System.Object, ByVal e As System.IO.Ports.SerialDataReceivedEventArgs) Handles SerialPort1.DataReceived
        While SerialPort1.BytesToRead > 0

            q.Enqueue(SerialPort1.ReadByte)
        End While


    End Sub

    Private Sub Timer1_Tick(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Timer1.Tick
        While q.Count > 0
            RichTextBox1.AppendText(ChrW(q.Dequeue()))
        End While
    End Sub

    Private Sub Button5_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button5.Click
        If TextBox1.Text.Length = 0 Then            ' Error if there is no send data 

            Exit Sub             ' Break out of processing 
        End If

        Try
            SerialPort1.Write(TextBox1.Text)     ' Write data to the send buffer 
            RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer 
        Catch ex As Exception           ' Exception handling 
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub Button6_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button6.Click
        RichTextBox1.Clear()



    End Sub

    Private Sub RichTextBox1_TextChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RichTextBox1.TextChanged

    End Sub

    Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
      

    End Sub

    Private Sub RichTextBox2_TextChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RichTextBox2.TextChanged

    End Sub

    Private Sub RadioButton1_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RadioButton1.CheckedChanged
        SerialPort1.Write("A")
        TextBox2.Text = "45..."
        RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer 
    End Sub

    Private Sub TextBox1_TextChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles TextBox1.TextChanged

    End Sub

    Private Sub RadioButton2_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RadioButton2.CheckedChanged
        SerialPort1.Write("B")
        TextBox2.Text = "90.."
        RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer 
    End Sub

    Private Sub MonthCalendar1_DateChanged(ByVal sender As System.Object, ByVal e As System.Windows.Forms.DateRangeEventArgs)

    End Sub

    Private Sub MenuStrip1_ItemClicked(ByVal sender As System.Object, ByVal e As System.Windows.Forms.ToolStripItemClickedEventArgs)

    End Sub

    Private Sub StatusStrip1_ItemClicked(ByVal sender As System.Object, ByVal e As System.Windows.Forms.ToolStripItemClickedEventArgs)

    End Sub

    Private Sub TextBox2_TextChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles TextBox2.TextChanged

    End Sub

    Private Sub ComboBox1_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs)

    End Sub

    Private Sub Button2_Click_1(ByVal sender As System.Object, ByVal e As System.EventArgs)
        SerialPort1.Write("1")
    End Sub

    Private Sub Button1_Click_1(ByVal sender As System.Object, ByVal e As System.EventArgs)
        ' If TextBox1.Text.Length = 0 Then            ' Error if there is no send data 

        ' Exit Sub             ' Break out of processing 
        'End If

        ' Try
        SerialPort1.Write(TextBox1.Text)     ' Write data to the send buffer 
        RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer 
        Exit Sub
        'Catch ex As Exception           ' Exception handling 
        ' MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        ' End Try
    End Sub


    Private Sub RadioButton3_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs)

    End Sub

    Private Sub RadioButton4_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RadioButton4.CheckedChanged
        SerialPort1.Write("H")
        TextBox2.Text = "360.."
        RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer
    End Sub

    Private Sub RadioButton5_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RadioButton5.CheckedChanged
        SerialPort1.Write("D")
        TextBox2.Text = "180.."
        RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer
    End Sub

    Private Sub RadioButton3_CheckedChanged_1(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RadioButton3.CheckedChanged
        SerialPort1.Write("F")
        TextBox2.Text = "270.."
        RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer
    End Sub

    Private Sub Button5_DragEnter(sender As Object, e As DragEventArgs) Handles Button5.DragEnter
        SerialPort1.Write(TextBox1.Text)
    End Sub

    Private Sub RadioButton7_CheckedChanged(sender As Object, e As EventArgs) Handles RadioButton7.CheckedChanged
        SerialPort1.Write("N")
        TextBox3.Text = "CounterClockwise"
    End Sub

    Private Sub RadioButton8_CheckedChanged(sender As Object, e As EventArgs) Handles RadioButton8.CheckedChanged
        SerialPort1.Write("R")
        TextBox3.Text = "Clockwise"
    End Sub

    Private Sub RadioButton12_CheckedChanged(sender As Object, e As EventArgs)


    End Sub



    Private Sub Button1_Click_2(sender As Object, e As EventArgs) Handles Button1.Click
        SerialPort1.Write("3")
        TextBox5.Text = "Motor:Running.."
    End Sub

    Private Sub RadioButton6_CheckedChanged(sender As Object, e As EventArgs) Handles RadioButton6.CheckedChanged
        SerialPort1.Write("C")
    End Sub

    Private Sub Button7_Click(sender As Object, e As EventArgs) Handles Button7.Click
        SerialPort1.Write("4")
        TextBox5.Text = "Motor:Stop.."
        TextBox3.Text = "Reset"
        RadioButton10.Checked = False
        RadioButton9.Checked = False
        RadioButton8.Checked = False
        RadioButton7.Checked = False
        RadioButton6.Checked = False
        RadioButton5.Checked = False
        RadioButton4.Checked = False
        RadioButton3.Checked = False
        RadioButton2.Checked = False
        RadioButton1.Checked = False
    End Sub

    Private Sub TextBox3_TextChanged(sender As Object, e As EventArgs) Handles TextBox3.TextChanged

    End Sub

    Private Sub TextBox4_TextChanged(sender As Object, e As EventArgs) Handles TextBox4.TextChanged

    End Sub

    Private Sub RadioButton9_CheckedChanged(sender As Object, e As EventArgs)
        SerialPort1.Write("8")
    End Sub

    Private Sub RadioButton10_CheckedChanged(sender As Object, e As EventArgs)
        SerialPort1.Write("9")
    End Sub

    Private Sub Button8_Click(sender As Object, e As EventArgs) Handles Button8.Click
        SerialPort1.Write("8")
        TextBox5.Text = "Motor Running.."
    End Sub

    Private Sub Form1_KeyPress(sender As Object, e As KeyPressEventArgs) Handles MyBase.KeyPress

    End Sub

    Private Sub TextBox5_TextChanged(sender As Object, e As EventArgs) Handles TextBox5.TextChanged

    End Sub

    Private Sub Button9_Click(sender As Object, e As EventArgs) Handles Button9.Click
        SerialPort1.Write("v")
        TextBox5.Text = "Origin position"
    End Sub

    Private Sub RadioButton9_CheckedChanged_1(sender As Object, e As EventArgs) Handles RadioButton9.CheckedChanged
        SerialPort1.Write("E")
        TextBox2.Text = "225.."
        RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer
    End Sub

    Private Sub RadioButton10_CheckedChanged_1(sender As Object, e As EventArgs) Handles RadioButton10.CheckedChanged
        SerialPort1.Write("G")
        TextBox2.Text = "315.."
        RichTextBox2.Text = (TextBox1.Text)     ' Write data to the send buffer
    End Sub

    Private Sub Label1_Click(sender As Object, e As EventArgs) Handles Label1.Click

    End Sub

    Private Sub GroupBox6_Enter(sender As Object, e As EventArgs) Handles GroupBox6.Enter

    End Sub

    Private Sub Button10_Click(sender As Object, e As EventArgs) Handles Button10.Click
        SerialPort1.Write("a")
    End Sub

    Private Sub Button11_Click(sender As Object, e As EventArgs) Handles Button11.Click
        SerialPort1.Write("b")
    End Sub
End Class
